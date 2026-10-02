import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_voice_bridge/gemma/data/gemma_downloader_datasource.dart';
import 'package:flutter_voice_bridge/gemma/domain/download_model.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakePathProvider extends PathProviderPlatform with MockPlatformInterfaceMixin {
  FakePathProvider(this.documentsPath);

  final String documentsPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}

/// Serves [modelBytes]; honours Range only when [supportsRange] is true.
Future<HttpServer> serveModel(List<int> modelBytes, {required bool supportsRange}) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((request) async {
    final range = request.headers.value(HttpHeaders.rangeHeader);
    final response = request.response;
    if (supportsRange && range != null) {
      final start = int.parse(range.replaceFirst('bytes=', '').replaceFirst('-', ''));
      if (start >= modelBytes.length) {
        response
          ..statusCode = HttpStatus.requestedRangeNotSatisfiable
          ..headers.set(HttpHeaders.contentRangeHeader, 'bytes */${modelBytes.length}');
      } else {
        response
          ..statusCode = HttpStatus.partialContent
          ..contentLength = modelBytes.length - start
          ..add(modelBytes.sublist(start));
      }
    } else {
      response
        ..contentLength = modelBytes.length
        ..add(modelBytes);
    }
    await response.close();
  });
  return server;
}

void main() {
  final modelBytes = List<int>.generate(4096, (index) => index % 251);
  late Directory documents;

  setUp(() {
    documents = Directory.systemTemp.createTempSync('gemma_download');
    PathProviderPlatform.instance = FakePathProvider(documents.path);
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() => documents.deleteSync(recursive: true));

  Future<File> download(HttpServer server, {List<int>? partial}) async {
    const fileName = 'model.task';
    if (partial != null) File('${documents.path}/$fileName.part').writeAsBytesSync(partial);
    final datasource = GemmaDownloaderDataSource(
      model: DownloadModel(modelUrl: 'http://${server.address.host}:${server.port}/model', modelFilename: fileName),
    );
    await datasource.downloadModel(token: '', onProgress: (_) {});
    return File('${documents.path}/$fileName');
  }

  test('a fresh download lands under the final name with no .part left', () async {
    final server = await serveModel(modelBytes, supportsRange: true);
    final file = await download(server);
    await server.close();

    expect(file.readAsBytesSync(), modelBytes);
    expect(File('${file.path}.part').existsSync(), isFalse);
  });

  test('resumes a partial download when the server honours Range', () async {
    final server = await serveModel(modelBytes, supportsRange: true);
    final file = await download(server, partial: modelBytes.sublist(0, 1000));
    await server.close();

    expect(file.readAsBytesSync(), modelBytes);
  });

  test('rewrites from scratch when the server ignores Range (200), instead of appending a second copy', () async {
    final server = await serveModel(modelBytes, supportsRange: false);
    final file = await download(server, partial: modelBytes.sublist(0, 1000));
    await server.close();

    expect(file.lengthSync(), modelBytes.length);
    expect(file.readAsBytesSync(), modelBytes);
  });

  test('treats 416 on a complete partial file as finished', () async {
    final server = await serveModel(modelBytes, supportsRange: true);
    final file = await download(server, partial: modelBytes);
    await server.close();

    expect(file.readAsBytesSync(), modelBytes);
  });

  test('a 416 for a partial file larger than the model deletes it instead of keeping a corrupt model', () async {
    final server = await serveModel(modelBytes, supportsRange: true);
    final oversized = [...modelBytes, 1, 2, 3];
    await expectLater(download(server, partial: oversized), throwsA(isA<HttpException>()));
    await server.close();

    expect(File('${documents.path}/model.task').existsSync(), isFalse);
    expect(File('${documents.path}/model.task.part').existsSync(), isFalse);
  });
}
