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

package android.apex;

import android.apex.ApexInfo;
import android.apex.ApexInfoList;
import android.apex.ApexSessionInfo;
import android.apex.ApexSessionParams;

interface IApexService {
   void submitStagedSession(in ApexSessionParams params, out ApexInfoList packages);
   void markStagedSessionReady(int session_id);
   void markStagedSessionSuccessful(int session_id);

   ApexSessionInfo[] getSessions();
   ApexSessionInfo getStagedSessionInfo(int session_id);
   ApexInfo[] getActivePackages();
   ApexInfo[] getAllPackages();

   void abortActiveSession();

   /**
    * Copies the CE apex data directory for the given user to the backup
    * location, and returns the inode of the snapshot directory.
    */
   long snapshotCeData(int user_id, int rollback_id, in @utf8InCpp String apex_name);

   /**
    * Restores the snapshot of the CE apex data directory for the given user and
    * apex.
    */
   void restoreCeData(int user_id, int rollback_id, in @utf8InCpp String apex_name);

   /**
    * Deletes device-encrypted snapshots for the given rollback id.
    */
   void destroyDeSnapshots(int rollback_id);

   void unstagePackages(in @utf8InCpp List<String> active_package_paths);

   /**
    * Returns the active package corresponding to |package_name| and null
    * if none exists.
    */
   ApexInfo getActivePackage(in @utf8InCpp String package_name);

   /**
    * Not meant for use outside of testing. The call will not be
    * functional on user builds.
    */
   void activatePackage(in @utf8InCpp String package_path);
   /**
    * Not meant for use outside of testing. The call will not be
    * functional on user builds.
    */
   void deactivatePackage(in @utf8InCpp String package_path);
   /**
    * Not meant for use outside of testing. The call will not be
    * functional on user builds.
    */
   void preinstallPackages(in @utf8InCpp List<String> package_tmp_paths);
   /**
    * Not meant for use outside of testing. The call will not be
    * functional on user builds.
    */
   void postinstallPackages(in @utf8InCpp List<String> package_tmp_paths);
   /**
    * Not meant for use outside of testing. The call will not be
    * functional on user builds.
    */
   void stagePackages(in @utf8InCpp List<String> package_tmp_paths);
   /**
    * Not meant for use outside of testing. The call will not be
    * functional on user builds.
    */
   void rollbackActiveSession();
   /**
    * Not meant for use outside of testing. The call will not be
    * functional on user builds.
    */
   void resumeRollbackIfNeeded();
}
