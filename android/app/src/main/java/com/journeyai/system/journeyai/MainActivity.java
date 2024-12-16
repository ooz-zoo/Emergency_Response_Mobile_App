package com.journeyai.system.journeyai;
import android.os.Bundle;  
import io.flutter.embedding.android.FlutterFragmentActivity;
import com.google.firebase.FirebaseApp;
import com.google.firebase.appcheck.FirebaseAppCheck;
import com.google.firebase.appcheck.debug.DebugAppCheckProviderFactory;

public class MainActivity extends FlutterFragmentActivity {
@Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState); 
        FirebaseApp.initializeApp(this);
        FirebaseAppCheck firebaseAppCheck = FirebaseAppCheck.getInstance();
        firebaseAppCheck.installAppCheckProviderFactory(
                DebugAppCheckProviderFactory.getInstance());
}
}

/*  The debug provider allows access to your Firebase resources from unverified devices. 
Don't use the debug provider in production builds of your app, and don't share your debug builds 
with untrusted parties.*/