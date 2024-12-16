-keep class com.stripe.android.** { *; }
-keep class com.reactnativestripesdk.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }
-keep class com.stripe.android.** { *; }
-keep class com.reactnativestripesdk.pushprovisioning.** { *; }
-keep class com.stripe.android.pushProvisioning.** { *; }
-keep class * extends com.stripe.android.pushProvisioning.** { *; }
-keep class * extends com.reactnativestripesdk.pushprovisioning.** { *; }
-keep class com.stripe.android.** { *; }
-keep class com.reactnativestripesdk.pushprovisioning.** { *; }
-keep class com.stripe.android.pushProvisioning.EphemeralKeyUpdateListener { *; }
-keep class com.reactnativestripesdk.pushprovisioning.EphemeralKeyProvider { *; }

# Keep the Stripe EphemeralKeyUpdateListener class
-keep class com.stripe.android.pushProvisioning.EphemeralKeyUpdateListener { *; }

# Keep the EphemeralKeyProvider class from react-native-stripe-sdk
-keep class com.reactnativestripesdk.pushprovisioning.EphemeralKeyProvider { *; }


# Please add these rules to your existing keep rules in order to suppress warnings.
# This is generated automatically by the Android Gradle plugin.
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivity$g
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Args
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Error
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningEphemeralKeyProvider
-dontwarn org.tensorflow.lite.gpu.GpuDelegateFactory$Options$GpuBackend
-dontwarn org.tensorflow.lite.gpu.GpuDelegateFactory$Options

-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivity$g
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Args
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Error
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningEphemeralKeyProvider
-dontwarn com.stripe.android.pushProvisioning.EphemeralKeyUpdateListener