output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "IDs of public subnets."
  value       = [for subnet in aws_subnet.public : subnet.id]
}

output "private_subnet_ids" {
  description = "IDs of private subnets."
  value       = [for subnet in aws_subnet.private : subnet.id]
}

output "nat_gateway_ids" {
  description = "IDs of NAT gateways created for the selected topology. Empty when NAT is disabled."
  value       = [for nat in aws_nat_gateway.this : nat.id]
}

output "private_route_table_ids" {
  description = "IDs of route tables associated with private subnets."
  value       = [for route_table in aws_route_table.private : route_table.id]
}
