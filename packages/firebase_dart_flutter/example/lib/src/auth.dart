import 'package:firebase_dart_flutter_example/src/widgets.dart';
import 'package:flutter/material.dart';
import 'package:firebase_dart/firebase_dart.dart';

class AuthTab extends StatelessWidget {
  final FirebaseApp app;

  final FirebaseAuth auth;

  AuthTab({Key? key, required this.app})
      : auth = FirebaseAuth.instanceFor(app: app),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    var email = TextEditingController();
    var password = TextEditingController();
    return StreamBuilder<User?>(
      stream: auth.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            children: [CircularProgressIndicator()],
            mainAxisAlignment: MainAxisAlignment.center,
          );
        }

        if (snapshot.data == null) {
          return Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                      child: Text('sign in with email and password'),
                      onPressed: () {
                        showDialog(
                            context: context,
                            builder: (context) =>
                                SignInWithEmailAndPasswordDialog(auth: auth));
                      }),
                  TextButton(
                      child: Text('sign in with google'),
                      onPressed: () async {
                        await auth.signInWithRedirect(GoogleAuthProvider());
                      }),
                  TextButton(
                      child: Text('sign in with facebook'),
                      onPressed: () async {
                        await auth.signInWithRedirect(FacebookAuthProvider());
                      }),
                  TextButton(
                    child: Text('send sign in link'),
                    onPressed: () async {
                      var email = await showEditFieldDialog(
                          context: context,
                          labelText: 'email',
                          title: 'Sign in with email link',
                          bodyText:
                              'Enter your email address and press OK. We\'ll send you an email to sign in',
                          onContinue: (email) async {
                            await auth.sendSignInLinkToEmail(
                                email: email,
                                actionCodeSettings: ActionCodeSettings(
                                    androidPackageName: 'com.example.example',
                                    iOSBundleId: 'com.example.example',
                                    handleCodeInApp: true,
                                    androidInstallApp: true,
                                    url: Uri.base.toString()));
                            return email;
                          });
                      if (email == null) return;
                      await showEditFieldDialog(
                          context: context,
                          labelText: 'email',
                          title: 'Sign in with email link',
                          bodyText:
                              'We\'ve sent you an email with a link to sign in. Please, click the link. You will be redirected to a blank page. Copy the url of this page and paste it in the below field.',
                          onContinue: (link) async {
                            await auth.signInWithEmailLink(
                                emailLink: link, email: email);
                          });
                    },
                  )
                ],
              ));
        }

        return UserInfo(
          auth: auth,
          user: snapshot.data!,
        );
      },
    );
  }
}

class UserInfo extends StatelessWidget {
  final User user;
  final FirebaseAuth auth;

  const UserInfo({Key? key, required this.auth, required this.user})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        MaterialButton(
            onPressed: () {
              showEditFieldDialog(
                title: 'Change profile picture',
                labelText: 'picture url',
                initialValue: user.photoURL,
                onContinue: (v) async {
                  await user.updateProfile(photoURL: v);
                },
                context: context,
              );
            },
            child: CircleAvatar(
                child: user.photoURL == null ? Icon(Icons.person) : null,
                backgroundImage: user.photoURL == null || user.photoURL!.isEmpty
                    ? null
                    : NetworkImage(user.photoURL!))),
        MaterialButton(
            onPressed: () {
              showEditFieldDialog(
                title: 'Change display name',
                labelText: 'display name',
                initialValue: user.displayName,
                onContinue: (v) async {
                  await user.updateProfile(displayName: v);
                },
                context: context,
              );
            },
            child: Text(user.displayName == null || user.displayName!.isEmpty
                ? '[no display name]'
                : user.displayName!)),
        MaterialButton(
            onPressed: () {
              showEditFieldDialog(
                title: 'Change email',
                labelText: 'email',
                initialValue: user.email,
                onContinue: (v) async {
                  await user.updateEmail(v);
                },
                context: context,
              );
            },
            child: Text(user.email == null || user.email!.isEmpty
                ? '[no email]'
                : user.email!)),
        if (!user.emailVerified)
          MaterialButton(
            onPressed: () {
              showConfirmDialog(
                title: 'Send email verification email',
                context: context,
                onContinue: () async {
                  await user.sendEmailVerification();
                },
              );
            },
            child: Text('verify email'),
          ),
        if (user.providerData.any((v) => v.providerId == 'password'))
          MaterialButton(
              onPressed: () {
                showEditFieldDialog(
                  title: 'Change password',
                  labelText: 'password',
                  obscureText: true,
                  onContinue: (v) async {
                    await user.updatePassword(v);
                  },
                  context: context,
                );
              },
              child: Text('password: ***')),
        TextButton(
          child: Text('sign out'),
          onPressed: () {
            auth.signOut();
          },
        )
      ],
    );
  }
}

class SignInWithEmailAndPasswordDialog extends StatelessWidget {
  final FirebaseAuth auth;

  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();

  SignInWithEmailAndPasswordDialog({Key? key, required this.auth})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ActionDialog(
      title: Text('Sign in with email and password'),
      onContinue: () async {
        await auth.signInWithEmailAndPassword(
          email: email.text,
          password: password.text,
        );
      },
      children: [
        TextField(
          controller: email,
          decoration: InputDecoration(labelText: 'email'),
        ),
        TextField(
          controller: password,
          decoration: InputDecoration(labelText: 'password'),
          obscureText: true,
        ),
      ],
    );
  }
}
