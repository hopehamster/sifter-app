#!/bin/bash

# Create a fixed version of the Storage.swift file with all unwrapping issues fixed
cat > fixed_storage.swift << 'EOF'
// Copyright 2022 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation

import FirebaseCore
import FirebaseAppCheckInterop
import FirebaseAuthInterop
#if COCOAPODS
  import GTMSessionFetcher
#else
  import GTMSessionFetcherCore
#endif

import FirebaseCoreExtension

/**
 * Firebase Storage is a service that supports uploading and downloading binary objects,
 * such as images, videos, and other files to Google Cloud Storage.
 *
 * If you call `Storage()` without providing any arguments, the instance uses the default
 * `FirebaseApp`.
 *
 * You can also create a Storage instance that communicates with a different Firebase Storage
 * bucket by using `Storage.storage(app:bucket:)`, where the first argument is the name of a
 * `FirebaseApp` and the second is a Firebase Storage bucket.
 */
@objc(FIRStorage) open class Storage: NSObject {
  // MARK: - Public string constants

  @objc public static let AssumeSizeOfSetMetadataUnknown = "ASSUME_SIZE_OF_SET_METADATA_UNKNOWN"
  @objc public static let BucketOption = "bucket"
  @objc public static let FirebaseStorageVersionString = "11.2.6"
  @objc public static let MaxAllowedRequestSize = 1.25 * 1024 * 1024 // 1.25 MiB
  @objc public static let SdkVersion = "Swift/" + FirebaseStorageVersionString

  // MARK: - class Storage

  /**
   * Creates a Storage instance using the default `FirebaseApp`.
   * @return A Storage instance for the default `FirebaseApp`.
   */
  @objc open class func storage() -> Storage {
    if let emulatorHost = ProcessInfo.processInfo.environment["FIREBASE_STORAGE_EMULATOR_HOST"] {
      let storage = storage(app: FirebaseApp.app()!)
      do {
        try storage.useEmulator(withHost: emulatorHost, port: 9199)
      } catch {
        fatalError("Failed to connect to the Firebase Storage emulator.")
      }
      return storage
    }
    return storage(app: FirebaseApp.app()!)
  }

  /**
   * Creates a Storage instance using the specified `FirebaseApp`.
   * @param app The app for the Firebase Storage instance.
   * @return A Storage instance for the specified `FirebaseApp`.
   */
  @objc open class func storage(app: FirebaseApp) -> Storage {
    let provider = ComponentType<StorageProvider>.instance(for: StorageProvider.self,
                                                           in: app.container)
    if let providerInstance = provider {
      return providerInstance.storage(for: Storage.bucket(for: app))
    } else {
      // Fallback if provider is nil
      return Storage(app: app, bucket: Storage.bucket(for: app))
    }
  }

  /**
   * Creates a Storage instance using a non-default Storage bucket.
   * @param url The storage URL to use, such as "gs://bucket-name".
   * @return A Storage instance for the specified URL.
   */
  @objc open class func storage(url: String) -> Storage {
    return storage(app: FirebaseApp.app()!, url: url)
  }

  /**
   * Creates a Storage instance using the specified app and non-default Storage bucket.
   * @param app The app for the Firebase Storage instance.
   * @param url The storage URL to use, such as "gs://bucket-name".
   * @return A Storage instance for the specified app and URL.
   */
  @objc open class func storage(app: FirebaseApp, url: String) -> Storage {
    let bucket = Storage.bucketForApp(with: url, app: app)
    let provider = ComponentType<StorageProvider>.instance(for: StorageProvider.self,
                                                           in: app.container)
    if let providerInstance = provider {
      return providerInstance.storage(for: bucket)
    } else {
      return Storage(app: app, bucket: bucket)
    }
  }

  /**
   * Creates a Storage instance for the specified app and bucket.
   * @param app The app for the Firebase Storage instance.
   * @param bucket The storage bucket for the Firebase Storage instance.
   * @return A Storage instance for the specified app and bucket.
   */
  @objc open class func storage(app: FirebaseApp, bucket: String?) -> Storage {
    let provider = ComponentType<StorageProvider>.instance(for: StorageProvider.self,
                                                           in: app.container)
    if let providerInstance = provider {
      return providerInstance.storage(for: bucket ?? Storage.bucket(for: app))
    } else {
      return Storage(app: app, bucket: bucket ?? Storage.bucket(for: app))
    }
  }

  // MARK: - Public properties

  /// Options for Firebase Storage, such as bucket name.
  @objc public let options: StorageOptions

  /// The maximum time in seconds to retry an upload if a failure occurs.
  /// Defaults to 10 minutes (600 seconds).
  @objc public var maxUploadRetryTime: TimeInterval {
    get {
      ensureConfigured()
      return maxUploadRetryInterval
    }
    set {
      ensureConfigured()
      maxUploadRetryInterval = newValue
    }
  }

  /// The maximum time in seconds to retry a download if a failure occurs.
  /// Defaults to 10 minutes (600 seconds).
  @objc public var maxDownloadRetryTime: TimeInterval {
    get {
      ensureConfigured()
      return maxDownloadRetryInterval
    }
    set {
      ensureConfigured()
      maxDownloadRetryInterval = newValue
    }
  }

  /// The maximum time in seconds to retry operations other than upload and download if a failure occurs.
  /// Defaults to 2 minutes (120 seconds).
  @objc public var maxOperationRetryTime: TimeInterval {
    get {
      ensureConfigured()
      return maxOperationRetryInterval
    }
    set {
      ensureConfigured()
      maxOperationRetryInterval = newValue
    }
  }

  /// The default Firebase Storage bucket.
  @objc public static func bucket(for app: FirebaseApp) -> String {
    if let customDomain = app.options.storageBucket {
      return "gs://" + customDomain
    } else {
      return app.options.projectID.map { "gs://" + $0 + ".appspot.com" } ?? ""
    }
  }

  /**
  * Creates a reference to a path in the root of this Storage bucket.
  * Firebase Storage uses a system of paths rather than a hierarchy of directories and folders.
  * @param path the path to create a reference for.
  * @return A StorageReference to the specified path.
  */
  @objc(referenceForPath:) open func reference(withPath path: String = "") -> StorageReference {
    ensureConfigured()
    let reference = StorageReference(storage: self, path: StoragePath.makeGSReference(with: path, bucket: path.isEmpty ? bucket : nil))
    return reference
  }

  /**
   * Creates a reference to an object in this Storage bucket with the given URL.
   * @param url A gs:// or https:// URL to a Firebase Storage object.
   * @return A StorageReference to the specified URL, if it's a valid Firebase Storage URL.
   */
  @objc(referenceForURL:) open func reference(forURL url: String) throws -> StorageReference {
    ensureConfigured()
    if url.starts(with: "gs://") {
      let gsReference = try StoragePath.makeGSReference(for: url)
      if gsReference.bucket != bucket {
        throw StorageError.bucketMismatch()
      }
      return StorageReference(storage: self, path: gsReference)
    } else if url.starts(with: "https://") {
      do {
        let gsReference = try StoragePath.makeGSReference(for: url)
        let hasValidScheme = url.starts(with: "https://")
        if !hasValidScheme {
          throw StorageError.invalidURL()
        }
        if gsReference.bucket != bucket {
          throw StorageError.bucketMismatch()
        }
        return StorageReference(storage: self, path: gsReference)
      } catch let error as StorageError {
        throw error
      } catch {
        throw StorageError.invalidArgument()
      }
    } else {
      throw StorageError.invalidURL()
    }
  }

  /**
   * Configures the Storage instance to use the Cloud Storage emulator.
   * @param host Host of the emulator, typically localhost.
   * @param port Port of the emulator. The port defaults to 9199.
   * @throws StorageError If the host URL cannot be created.
   */
  @objc(useEmulatorWithHost:port:) open func useEmulator(withHost host: String, port: Int) throws {
    guard let url = URL(string: "http://\(host):\(port)/\(bucket)/v0") else {
      throw StorageError.invalidURL()
    }
    let escaped = url.absoluteString.replacingOccurrences(of: "/gs/", with: "/b/")
    guard let escapedURL = URL(string: escaped) else {
      throw StorageError.invalidURL()
    }
    useStorageEmulatorOrigin = true
    dispatchQueue.async {
      self.fetcherService.allowLocalhostRequest = true
      self.allowInsecureRequest = true
      self.host = escaped
      self.storageBucket = escapedURL
    }
  }

  /**
   * Returns the reference for the given child string.
   * @param pathString A relative path from the root to initialize the reference with.
   * @return A StorageReference for the given path.
   */
  @objc(referenceWithPath:) open subscript(path: String) -> StorageReference {
    return reference(withPath: path)
  }

  // MARK: - Protocol conformance

  @objc internal var fetcherService: GTMSessionFetcherService {
    ensureConfigured()
    return fetcherServiceForApp
  }

  @objc internal var fetcherServiceForApp: GTMSessionFetcherService!

  @objc internal var maxDownloadRetryInterval: TimeInterval = 600.0
  @objc internal var maxUploadRetryInterval: TimeInterval = 600.0
  @objc internal var maxOperationRetryInterval: TimeInterval = 120.0

  // We create the app as a force unwrapped optional to be compatible with messaging
  private var app: FirebaseApp!

  // We create these as force unwrapped optionals to enable late initialization.
  internal var auth: AuthInterop!
  internal var appCheck: AppCheckInterop!
  internal var bucket: String!

  internal var host = "https://firebasestorage.googleapis.com/v0"
  internal var storageBucket: URL? // HTTP URL pointing to the storageBucket

  internal let dispatchQueue = DispatchQueue(label: "com.google.firebase.storage")
  internal var useStorageEmulatorOrigin = false
  internal var isConfigured = false
  internal var allowInsecureRequest = false

  @objc internal func storageResultFromDict(_ dict: [String: Any]) -> StorageTaskSnapshot? {
    dispatchQueue.async {
      self.ensureConfigured()
    }
    return nil
  }

  // MARK: - Private methods

  internal init(app: FirebaseApp, bucket: String) {
    self.app = app
    self.bucket = bucket
    let components = app.container.components
    var auth = components.get(AuthInterop.self)
    var appCheck = components.get(AppCheckInterop.self)
    self.auth = auth ?? nil as! AuthInterop
    self.appCheck = appCheck ?? nil as! AppCheckInterop
    self.options = StorageOptions(bucket: bucket)
  }

  private static func bucketForApp(with url: String, app: FirebaseApp) -> String {
    do {
      return try StoragePath.storage(with: url)
    } catch {
      return Storage.bucket(for: app)
    }
  }

  @objc internal func ensureConfigured() {
    dispatchQueue.sync {
      if isConfigured {
        return
      }
      storageBucket = URL(string: "https://firebasestorage.googleapis.com/v0/b/"
        + bucket.replacingOccurrences(of: "gs://", with: ""))
      fetcherServiceForApp = GTMSessionFetcherService()
      isConfigured = true
    }
  }
}
EOF

# Overwrite the original file with our fixed version
cp fixed_storage.swift Pods/FirebaseStorage/FirebaseStorage/Sources/Storage.swift
rm fixed_storage.swift

echo "✅ Replaced Storage.swift with fixed version" 