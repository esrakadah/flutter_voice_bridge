Pod::Spec.new do |s|
  s.name             = 'ffmpeg_kit_flutter'
  s.version          = '6.0.3'
  s.summary          = 'FFmpeg Kit for Flutter (local)'
  s.description      = 'A Flutter plugin for running FFmpeg and FFprobe commands with a local xcframework.'
  s.homepage         = 'https://github.com/arthenica/ffmpeg-kit'
  s.license          = { :file => '../../../../.pub-cache/hosted/pub.dev/ffmpeg_kit_flutter-6.0.3/LICENSE' }
  s.author           = { 'ARTHENICA' => 'open-source@arthenica.com' }
  s.source           = { :path => '.' }

  s.platform         = :osx, '10.15'
  s.requires_arc     = true
  s.static_framework = true

  s.source_files     = '../../../../.pub-cache/hosted/pub.dev/ffmpeg_kit_flutter-6.0.3/macos/Classes/**/*'
  s.public_header_files = '../../../../.pub-cache/hosted/pub.dev/ffmpeg_kit_flutter-6.0.3/macos/Classes/**/*.h'

  s.vendored_frameworks = 'ffmpeg-kit-https.xcframework'

  s.dependency 'FlutterMacOS'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end 