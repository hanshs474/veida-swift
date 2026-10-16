Pod::Spec.new do |s|
  s.name             = 'Veida'
  s.version          = '1.0.0'
  s.summary          = 'Veida AI image generation and editing for iOS and macOS.'
  s.description      = 'Veida AI is an unlimited free AI image generator. This pod turns a prompt into an image, or edits an image, and returns a CDN link. Works on the free tier with no API key.'
  s.homepage         = 'https://veida.ai/?utm_source=cocoapods&utm_medium=podspec'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Veida AI' => 'support@veida.ai' }
  s.source           = { :git => 'https://github.com/hanshs474/veida-swift.git', :tag => s.version.to_s }
  s.ios.deployment_target = '15.0'
  s.osx.deployment_target = '12.0'
  s.swift_versions   = ['5.7']
  s.source_files     = 'Sources/Veida/**/*.swift'
end
