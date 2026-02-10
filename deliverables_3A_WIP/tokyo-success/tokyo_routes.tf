# Explanation: kandagawa returns traffic to Liberdade—because doctors need answers, not one-way tunnels.

resource "aws_route" "kandagawa_to_sp_route01" {
  route_table_id         = aws_route_table.kandagawa_private_rt01.id
  destination_cidr_block = var.saopaulo_vpc_cidr  # Will come from São Paulo outputs
  transit_gateway_id     = aws_ec2_transit_gateway.kandagawa_tgw01.id
}

# # I'll add route to TGW for São Paulo CIDR in other private route tables if at any point i need them.
# resource "aws_route" "kandagawa_to_sp_route02" {
#   count = length(aws_route_table.kandagawa_private_rt) > 1 ? 1 : 0
  
#   route_table_id         = aws_route_table.kandagawa_private_rt[1].id
#   destination_cidr_block = var.saopaulo_vpc_cidr
#   transit_gateway_id     = aws_ec2_transit_gateway.kandagawa_tgw01.id
# }