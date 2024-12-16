import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:journeyai/pages/ern/driver_home.dart';
import 'package:journeyai/pages/ern/e_alert.dart';
import 'package:journeyai/pages/ern/e_contact_list.dart';
import 'package:journeyai/pages/ern/e_dashboard.dart';
import 'package:journeyai/pages/ern/e_empty.dart';
import 'package:journeyai/pages/ern/e_input_form.dart';
import 'package:journeyai/pages/ern/e_location.dart';
import 'package:journeyai/pages/ern/e_logs.dart';
import 'package:journeyai/pages/ern/test_file.dart';
import 'package:journeyai/pages/ern/test_send_notification.dart';
import 'package:journeyai/pages/login/login_page.dart';
import 'package:journeyai/pages/login/registration_page.dart';
import 'package:journeyai/pages/main_home.dart';
import 'package:journeyai/pages/auth_wrapper.dart';
//import 'package:intelligent_payment_system/rough%20pages/edit_profile.dart';
import 'package:journeyai/pages/profile.dart';
import 'package:journeyai/pages/wallet.dart';
import 'package:journeyai/services/consts.dart';
import 'package:journeyai/services/firebase_options.dart';
import '../pages/login_page.dart';
import '../pages/sign_up_page.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import '../pages/audio/audio_player.dart';
import 'package:journeyai/pages/ern/firebase_api.dart';
import 'package:journeyai/pages/ern/hive_local_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  await _setup();
  runApp(const MyApp());
}

Future<void> _setup() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await FirebaseApi().initNotifications();

  await Hive.initFlutter();
  Hive.registerAdapter(DriverConditionAdapter());
  await Hive.openBox<DriverCondition>('driverConditions');

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  //FirebaseFirestore.instance.settings = Settings(persistenceEnabled: false);

  Stripe.publishableKey = stripePublishableKey;
  await FirebaseAppCheck.instance.activate(
    //webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
    androidProvider: AndroidProvider.debug,
    // appleProvider: AppleProvider.debug,
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      //home: ScanPage(),
      // home: MainHome(),
      // home: DriverHome(),
      //home: LornaLoginPage(),
      home: AuthWrapper(),
      //    home: AudioPlayerWidget(),
      //   home: WalletPage(),
      routes: {
        '/main_home': (context) => MainHome(), // New route
        '/login': (context) => LoginPage(),
        '/signup': (context) => RegistrationPage(),
        '/empty': (context) => const EmptyApp(),
        '/contact_form': (context) => const FormScreen(),
        '/e_dashboard': (context) => DashboardScreen(detectedCondition: 'Unknown', detectedTime: DateTime.now()),
        //'/location': (context) => const LocationScreen(),
        '/alerts': (context) => AlertScreen(),
        '/logs': (context) => LogScreen(),
        '/payment': (context) => WalletPage(),
        '/llogin': (context) => LornaLoginPage(),
        '/lsignup': (context) => LornaRegistrationPage(),
        '/auth': (context) => AuthWrapper(),
        '/profile': (context) => ProfilePage(),
        '/driver': (context) => DriverHome(),
        '/audioman': (context) => AudioPlayerWidget(),
        '/contact_list': (context) => ContactScreen(),
        '/test' : (context) => TestFirebaseStorage(),
        'fcm' : (context) => PushNotificationService(),
      },
    );
  }
}

/* home: Scaffold(
        backgroundColor: Color(0xFF2D3436),
        appBar: AppBar(
          title: Text("Journey AI"),
          backgroundColor: Color(0xFFD63031),
          elevation: 2,
          actions: [IconButton(onPressed: () {}, icon: Icon(Icons.logout))],
        ),
        body: Center(
            child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LoginPage(),
              ),
            );
          },
          child: Center(
            child: Container(
              height: 60,
              width: 350,
              color: Color(0xFFD63031),
              child: Text("Login"),
            ),
          ),
        )),
      ),*/
