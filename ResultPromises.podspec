#
# Be sure to run `pod lib lint ResultPromises.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'ResultPromises'
  s.version          = '0.1.1'
  s.summary          = 'Promises for orginising asychronouse operation like sequences.'

  s.description      = <<-DESC
Provide generic Result and Promises types, that allows to organise async calls as sequance of events and monades. Promises can be mixed with  other Promises, Results and throwable closures.
                       DESC

  s.homepage         = 'https://github.com/Michael-Vorontsov/ResultPromises'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Mykhailo Vorontsov' => 'michel06@ukr.net' }
  s.source           = { :git => 'https://github.com/Michael-Vorontsov/ResultPromises.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.source_files = 'ResultPromises/Sources/**/*'
  
end
