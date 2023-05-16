variable "repositories" {
  type = list(object({
    name                  = string
    description           = string
    visibility            = string
    environment_variables = list(string)
  }))

  validation {
    condition     = alltrue([for o in var.repositories : contains(["public", "private"], o.visibility)])
    error_message = "Must be either \"public\" or \"private\"."
  }
}

