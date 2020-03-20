/*
 * Copyright (C) 2018 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "apex_manifest.h"
#include <android-base/file.h>
#include <android-base/logging.h>
#include <android-base/strings.h>
#include "apex_constants.h"
#include "string_log.h"

#include <google/protobuf/util/json_util.h>
#include <memory>
#include <string>

using android::base::EndsWith;
using android::base::Error;
using android::base::Result;
using google::protobuf::util::JsonParseOptions;

namespace android {
namespace apex {
namespace {

Result<void> JsonToApexManifestMessage(const std::string& content,
                                       ApexManifest* apex_manifest) {
  JsonParseOptions options;
  options.ignore_unknown_fields = true;
  auto parse_status = JsonStringToMessage(content, apex_manifest, options);
  if (!parse_status.ok()) {
    return Error() << "Failed to parse APEX Manifest JSON config: "
                   << parse_status.error_message().as_string();
  }
  return {};
}

}  // namespace

Result<ApexManifest> ParseManifestJson(const std::string& content) {
  ApexManifest apex_manifest;
  Result<void> parse_manifest_status =
      JsonToApexManifestMessage(content, &apex_manifest);
  if (!parse_manifest_status.ok()) {
    return parse_manifest_status.error();
  }

  // Verifying required fields.
  // name
  if (apex_manifest.name().empty()) {
    return Error() << "Missing required field \"name\" from APEX manifest.";
  }

  // version
  if (apex_manifest.version() == 0) {
    return Error() << "Missing required field \"version\" from APEX manifest.";
  }
  return apex_manifest;
}

Result<ApexManifest> ParseManifest(const std::string& content) {
  ApexManifest apex_manifest;
  std::string err;

  if (!apex_manifest.ParseFromString(content)) {
    return Error() << "Can't parse APEX manifest.";
  }

  // Verifying required fields.
  // name
  if (apex_manifest.name().empty()) {
    return Error() << "Missing required field \"name\" from APEX manifest.";
  }

  // version
  if (apex_manifest.version() == 0) {
    return Error() << "Missing required field \"version\" from APEX manifest.";
  }
  return apex_manifest;
}

std::string GetPackageId(const ApexManifest& apexManifest) {
  return apexManifest.name() + "@" + std::to_string(apexManifest.version());
}

Result<ApexManifest> ReadManifest(const std::string& path) {
  std::string content;
  if (!android::base::ReadFileToString(path, &content)) {
    return Error() << "Failed to read manifest file: " << path;
  }
  if (EndsWith(path, kManifestFilenameJson)) {
    return ParseManifestJson(content);
  }
  return ParseManifest(content);
}

}  // namespace apex
}  // namespace android
