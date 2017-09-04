#!/usr/bin/env bash
export FrameworkPathOverride=/Library/Frameworks/Mono.framework/Versions/Current/lib/mono/4.6.1-api
dotnet restore
dotnet build
