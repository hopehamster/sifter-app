#!/bin/bash
cd "Pods/Target Support Files"
ln -sf "BoringSSL-GRPC" "BoringSSLRPC"
cd BoringSSLRPC
ln -sf BoringSSL-GRPC.modulemap BoringSSLRPC.modulemap
