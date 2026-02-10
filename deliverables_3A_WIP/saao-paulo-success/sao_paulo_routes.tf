# sao_paulo_routes.tf
resource "aws_route" "liberdade_to_tokyo_route01" {
  route_table_id         = aws_route_table.liberdade_private_rt01.id
  destination_cidr_block = local.tokyo_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.liberdade_tgw01.id
}