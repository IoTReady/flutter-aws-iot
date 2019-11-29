import AWSIoT
import AWSMobileClient
import Flutter
import plugin_scaffold
import UIKit

public class SwiftAwsIotPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let methods = PluginMethods()
        _ = createPluginScaffold(
            messenger: registrar.messenger(),
            channelName: "com.scientifichackers.aws_iot",
            methodMap: [
                "attachPolicy": methods.attachPolicy
            ]
        )
    }
}

class PluginMethods {
    let mobileClient = AWSMobileClient.default()

    func attachPolicy(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let map = call.arguments as! [String: Any?]
        let identityId = map["identityId"] as! String
        let policyName = map["policyName"] as! String
        let region = map["region"] as! String

        let key = "com.scientifichackers.aws_iot/AWSIoT"
        AWSIoT.register(
            with: AWSServiceConfiguration(
                region: AwsIotPlugin.parseAWSRegion(region),
                credentialsProvider: mobileClient
            ),
            forKey: key
        )
        let iot = AWSIoT(forKey: key)

        let attachPolicyReq = AWSIoTAttachPolicyRequest()!
        attachPolicyReq.policyName = policyName
        attachPolicyReq.target = identityId

        iot.attachPolicy(attachPolicyReq, completionHandler: { error in
            if let error = error {
                trySendError(result, error)
            } else {
                trySend(result)
            }
        })
    }
}
