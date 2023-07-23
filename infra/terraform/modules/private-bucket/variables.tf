variable "name-prefix" {
  type = string
}

variable "services-grant-put" {
  type = list(string)
  default = []
}