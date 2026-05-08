terraform {
  backend "local" {
    path = "state/statuspulse.tfstate"
  }
}
