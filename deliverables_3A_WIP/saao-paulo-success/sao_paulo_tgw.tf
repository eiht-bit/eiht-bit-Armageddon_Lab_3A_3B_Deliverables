resource "aws_ec2_transit_gateway" "liberdade_tgw01" {
  description = "liberdade-tgw01 (Sao Paulo spoke)"
  
  tags = {
    Name = "liberdade-tgw01"
  }
}

# Explanation: Liberdade accepts the corridor from kandagawa—permissions are explicit, not assumed.
resource "aws_ec2_transit_gateway_peering_attachment_accepter" "liberdade_accept_peer01" {
  transit_gateway_attachment_id = "tgw-attach-077a14198fcf50d7f"
  tags = { Name = "liberdade-accept-peer01" }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "liberdade_attach_sp_vpc01" {
  transit_gateway_id = aws_ec2_transit_gateway.liberdade_tgw01.id
  vpc_id             = aws_vpc.liberdade_vpc01.id
  subnet_ids         = aws_subnet.liberdade_private_subnets[*].id
  
  tags = {
    Name = "liberdade-attach-sp-vpc01"
  }
}