# Hardware Abstraction Layer (HAL) for iOS

- CI Pipeline @ https://mobile-ci.devops.fds.com/jenkins/view/halIos/
- Artifactory @ http://ci-artifacts.devops.fds.com/artifactory/webapp/#/artifacts/browse/tree/General/mobileapps/halIos

# To build HAL

- Clone the repo
- Change directory to `halIos/HAL-iOS/Git Projects`
- Clone the HAL API project (https://code.devops.fds.com/stores/HALApi)
- Clone the Single Sign On (SSO) project (https://code.devops.fds.com/stores/sso)
- Build the SSO project acording to the instructions on the SSO README. (Currently titled "Installing in HAL")
- Open `HAL-iOS.xcworkspace` and build

## If building Hal for the first time on a machine
Note: If you try to build and get the "No such module: JWT" error then run the following steps.
- run `sudo gem install cocoapods`
- run `pod install`