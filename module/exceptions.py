#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
class WallabyValidateError(Exception):
   def __init__(self, invalids_map, error_map, list):
      self.invalids = invalids_map
      self.errors = error_map
      self.ask_list = list

class WallabyError(Exception):
   def __init__(self, error_map):
      self.errors = error_map

class ValidateWarning(Exception):
   def __init__(self, warnings):
      self.warnings = warnings

class WallabyStoreError(Exception):
   def __init__(self, string):
      self.error_str = string

class WallabyUnsupportedAPI(Exception):
   def __init__(self, major, minor=0):
      self.major = major
      self.minor = minor
