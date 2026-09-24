enum SocialAuthProvider { google, facebook, tiktok }

extension SocialAuthProviderLabel on SocialAuthProvider {
  String get label => switch (this) {
        SocialAuthProvider.google => 'Google',
        SocialAuthProvider.facebook => 'Facebook',
        SocialAuthProvider.tiktok => 'TikTok',
      };
}
