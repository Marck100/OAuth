# OAuth

OAuth helps you authenticate your request with OAuth1 protocol.
It's very easy to use and needs basic information:
- consumerKey
- consumerSecretKey
...
and you can add parameters to the authorization field or others.

## Let's start

1) Provide `consumerKey` and `consumerSecretKey`

```swift
OAuth.setConsumer(consumerKey: "xxx", consumerSecret: "xxx")
```

2) Generate your request
> Oauth generates most of the oauth parameters:
> - `oauth_signature_method`
> - `oauth_timestamp`
> - `oauth_nonce`
> - `oauth_version`
> - `oauth_signature`

But you can add extra parameters to the authorization header

```swift
let url = URL(string: "xxx")

let request = OAuth.shared.request(url, method: .post, oauthParameters: nil, parameters: nil)
```

3)  Post your request

```swift
PostCenter.shared.post(request, completionHandler: completionHandler)
```

Oauth can also remember some key information like `token`, `tokenSecret` and `verifier` which will automatically be included in the authentication header as you update them.

```swift
OAuth.shared.setToken(token: "xxx", tokenSecret: "xxx")
OAuth.shared.setVerifier(verifier: "xxx")
```


