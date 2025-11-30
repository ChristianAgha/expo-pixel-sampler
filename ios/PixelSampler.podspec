Pod::Spec.new do |s|
  s.name           = 'PixelSampler'
  s.version        = '1.0.0'
  s.summary        = 'Native pixel color sampling for React Native'
  s.description    = 'A native Swift module for instant pixel color sampling from images'
  s.homepage       = 'https://github.com/ChristianAgha/expo-pixel-sampler'
  s.license        = 'MIT'
  s.author         = 'Christian Agha <christianagha@gmail.com>'
  s.platform       = :ios, '15.1'
  s.source         = { :git => 'https://github.com/ChristianAgha/expo-pixel-sampler.git', :tag => s.version.to_s }
  s.source_files   = '*.swift'
  s.swift_version  = '5.4'
  
  s.dependency 'ExpoModulesCore'
end

