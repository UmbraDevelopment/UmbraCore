# UmbraCore Cryptographic Services: Quick Reference Guide

## Choosing the Right Implementation

| Feature | Standard | Apple Platform | Cross-Platform |
|---------|----------|---------------|----------------|
| **Primary Encryption** | AES-256-CBC | AES-256-GCM | ChaCha20-Poly1305 |
| **Primary Hashing** | SHA-256 | SHA-256 | BLAKE3 |
| **Key Derivation** | PBKDF2 | PBKDF2 (Hardware-accelerated) | Argon2id |
| **Hardware Acceleration** | No | Yes | No |
| **Memory Safety** | Standard | Enhanced | Enhanced |
| **Constant-time Operations** | Partial | Yes | Yes |
| **Platform Support** | All | Apple only | All |

## One-Minute Implementation Guide

### Standard Implementation (General Purpose)

```swift
// For general use cases with balanced security and compatibility
let cryptoService = await CryptoServiceRegistry.createService(
    type: .standard,
    secureStorage: mySecureStorage,
    logger: myLogger
)

// Prefer AES-256-CBC mode for best compatibility
let options = EncryptionOptions.standard(
    algorithm: .aes256CBC,
    mode: .cbc,
    padding: .pkcs7
)
```

**Best for:** General-purpose applications, compatibility with legacy systems, consistent behaviour across environments.

### Apple Platform Implementation (Apple-Optimised)

```swift
// For Apple platforms with hardware acceleration
let cryptoService = await CryptoServiceRegistry.createService(
    type: .applePlatform,
    secureStorage: mySecureStorage,
    logger: myLogger
)

// AES-GCM provides authenticated encryption
let options = EncryptionOptions.standard(
    algorithm: .aes256GCM,
    mode: .gcm
)
```

**Best for:** Apple-only applications requiring maximum performance, hardware security features, or Secure Enclave integration.

### Cross-Platform Implementation (Consistent Security)

```swift
// For cross-platform applications requiring consistent security
let cryptoService = await CryptoServiceRegistry.createService(
    type: .crossPlatform,
    secureStorage: mySecureStorage,
    logger: myLogger
)

// ChaCha20-Poly1305 provides authenticated encryption
// with strong protection against timing attacks
let options = EncryptionOptions.standard(
    algorithm: .chacha20Poly1305
)
```

**Best for:** Security-critical applications, cross-platform consistency, defence against side-channel attacks.

## Common Operations Quick Reference

### Encryption and Decryption

```swift
// Encrypt data
let encryptResult = await cryptoService.encrypt(
    dataIdentifier: "data-id",
    keyIdentifier: "key-id",
    options: options // Optional
)

// Decrypt data
if case .success(let encryptedId) = encryptResult {
    let decryptResult = await cryptoService.decrypt(
        dataIdentifier: encryptedId,
        keyIdentifier: "key-id",
        options: options // Optional
    )
}
```

### Key Generation

```swift
// Generate a random key
let keyResult = await cryptoService.generateKey(
    identifier: "my-key-id"
)

// Generate a password-derived key
let passwordOptions = KeyGenerationOptions.passwordDerived(
    password: "secure-passphrase",
    algorithm: .argon2id // or .pbkdf2
)

let keyResult = await cryptoService.generateKey(
    identifier: "password-key-id",
    options: passwordOptions
)
```

### Hashing and Verification

```swift
// Compute a hash
let hashResult = await cryptoService.computeHash(
    dataIdentifier: "data-id",
    options: HashOptions.standard(algorithm: .sha256)
)

// Verify a hash
if case .success(let hashId) = hashResult {
    let verifyResult = await cryptoService.verifyHash(
        dataIdentifier: "data-id",
        hashIdentifier: hashId
    )
}
```

## Common Error Patterns

```swift
// Always check for errors
switch encryptResult {
case .success(let encryptedId):
    // Handle success
    print("Encryption successful: \(encryptedId)")
    
case .failure(let error):
    // Map the error for more details
    let mappedError = CryptoErrorMapper.map(storageError: error)
    
    // Handle specific error types
    switch mappedError.code {
    case .invalidInput:
        print("Invalid input: \(mappedError.message)")
    case .invalidKeySize:
        print("Invalid key size: \(mappedError.message)")
    case .encryptionFailed:
        print("Encryption failed: \(mappedError.message)")
    default:
        print("Error: \(mappedError.message)")
    }
}
```

## Best Practices Summary

1. **Always validate inputs** - Use the validation helpers to ensure your inputs are valid
2. **Use authenticated encryption** - Prefer GCM or ChaCha20-Poly1305 for sensitive data
3. **Never reuse nonces/IVs** - Let the implementation generate these for you
4. **Handle errors properly** - Check all return values and handle errors appropriately
5. **Use strong key derivation** - Argon2id is preferred for password-based keys
6. **Consider memory safety** - The Apple and Cross-Platform implementations offer enhanced memory protection
7. **Document your choices** - Record which algorithms and options you've selected
8. **Test thoroughly** - Verify that your implementation works as expected across all target environments

## Security Considerations

- **Memory Management:** The Apple and Cross-Platform implementations provide better protection against memory-based attacks
- **Side-Channel Attacks:** The Cross-Platform implementation provides the strongest protection against timing attacks
- **Key Management:** Consider using the Apple implementation with Secure Enclave on supported devices
- **Authentication:** Always use authenticated encryption modes (GCM, ChaCha20-Poly1305) when possible
- **Auditing:** Log cryptographic operations but ensure sensitive data is properly redacted

## Compatibility Notes

- Files encrypted with the Standard implementation (AES-CBC) can only be decrypted by the Standard implementation
- Files encrypted with the Apple implementation (AES-GCM) can only be decrypted by the Apple implementation
- Files encrypted with the Cross-Platform implementation (ChaCha20-Poly1305) can only be decrypted by the Cross-Platform implementation
- Hash values can generally be verified by any implementation that supports the same algorithm
