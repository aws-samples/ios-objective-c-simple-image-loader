## ios-objective-c-simple-image-loader

This repository contains the code for a very simple app for iOS that will download an image from a given URL and display it (see screenshot below). More context is given in <a href="https://aws.amazon.com/blogs/networking-and-content-delivery/optimize-content-delivery-for-mobile-devices-with-amazon-cloudfront/">this AWS blog post, <em>Optimize content delivery for mobile devices with Amazon CloudFront</em></a>.

In addition, the app uses the [Network](https://developer.apple.com/documentation/network) framework's `nw_path_monitor_t` observer to monitor the network path that is available to the device. If the path is flagged as being *constrained*, then an additional header, `Save-Data: on` is added to the HTTP request used to download the image. The *constrained* flag typically indicates use of a mobile data connection with the Low Data Mode toggle on (in iOS Settings > Mobile Data). The infrastructure serving the objects can detect the presence of the `Save-Data: on` flag and in this case return more highly compressed images, lower resolution video artefacts and so on. The app reports the size of the downloaded object to make it obvious whether the infrastructure is correctly interpreting this header.

The application is written in Objective C and intended to be built using Apple's Xcode IDE.

<kbd><img src="screenshot.png"></kbd>

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.

