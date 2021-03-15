variable "prefix" {
  description = "Used for resource group name and as prefix to names of all resources in this template"
}

variable "publickeypath" {
  type    = string
  default = "~/.ssh/id_rsa.pub"
  description = "Public key used for SSH into VMs"
}

variable "connectedk8s_source" {
  type    = string
  default = "https://arcextensions.blob.core.windows.net/extensions/connectedk8s-0.3.8-py2.py3-none-any.whl"
  description = "Location of .whl file from where the extension is to be installed. If left unspecified, latest version is used"
}

variable "k8s_extension_source" {
  type    = string
  default = "https://arcextensions.blob.core.windows.net/extensions/k8s_extension-0.1PP.13-py2.py3-none-any.whl"
  description = "Location of .whl file from where the extension is to be installed. If left unspecified, latest version is used"
}

variable "k8sconfiguration_source" {
  type    = string
  default = ""
  description = "Location of .whl file from where the extension is to be installed. If left unspecified, latest version is used"
}