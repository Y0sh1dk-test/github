resource "github_repository" "this" {
  for_each = { for repository in var.repositories : repository.name => repository }

  name        = each.value.name
  description = each.value.description

  visibility = each.value.visibility
}
