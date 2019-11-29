package com.scientifichackers.aws_iot

import android.content.Context
import com.amazonaws.mobile.client.AWSMobileClient
import com.amazonaws.regions.Region
import com.amazonaws.services.iot.AWSIotClient
import com.amazonaws.services.iot.model.AttachPolicyRequest
import com.pycampers.plugin_scaffold.createPluginScaffold
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar

class AwsIotPlugin {
    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            createPluginScaffold(
                registrar.messenger(),
                "com.scientifichackers.aws_iot",
                AwsIotMethods(registrar.context())
            )
        }
    }
}

class AwsIotMethods(val context: Context) {
    val mobileClient = AWSMobileClient.getInstance()

    fun attachPolicy(call: MethodCall, result: Result) {
        val identityId = call.argument<String>("identityId")!!
        val policyName = call.argument<String>("policyName")!!
        val region = call.argument<String>("region")!!

        val attachPolicyReq = AttachPolicyRequest()
        attachPolicyReq.policyName = policyName
        attachPolicyReq.target = identityId

        val iotClient = AWSIotClient(mobileClient)
        iotClient.setRegion(Region.getRegion(region))
        iotClient.attachPolicy(attachPolicyReq)

        result.success(null)
    }
}
