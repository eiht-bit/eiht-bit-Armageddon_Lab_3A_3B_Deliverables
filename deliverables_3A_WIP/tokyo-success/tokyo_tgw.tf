# Explanation: Kandagawa is the river—Tokyo is the data authority.

resource "aws_ec2_transit_gateway" "kandagawa_tgw01" {
  description = "kandagawa-tgw01 (Tokyo hub)"
  
  # I need this for cross-region peering
  auto_accept_shared_attachments = "disable"
  
  tags = {
    Name = "kandagawa-tgw01"
  }
}

# Explanation: kandagawa connects to the Tokyo VPC—this is the gate to the medical records vault.
resource "aws_ec2_transit_gateway_vpc_attachment" "kandagawa_attach_tokyo_vpc01" {
  transit_gateway_id = aws_ec2_transit_gateway.kandagawa_tgw01.id
  vpc_id             = aws_vpc.kandagawa_vpc01.id
  subnet_ids         = aws_subnet.kandagawa_private_subnets[*].id
  
  tags = {
    Name = "kandagawa-attach-tokyo-vpc01"
  }
}

#Explanation: kandagawa opens a corridor request to Liberdade—compute may travel, data may not.
#Note: This depends on São Paulo TGW being created first. I'll use a data source for São Paulo TGW ID
#For now, I'll create the attachment without peer_transit_gateway_id and update later
resource "aws_ec2_transit_gateway_peering_attachment" "kandagawa_to_liberdade_peer01" {
  transit_gateway_id = aws_ec2_transit_gateway.kandagawa_tgw01.id
  peer_region        = "sa-east-1"
  
  # This will be populated after São Paulo deploys its TGW so i'll leave this commented for now - I'll update later deploys
  peer_transit_gateway_id = "tgw-0d2d0a23949aa5e1d" # why? i hate variables!
  
  tags = {
    Name = "kandagawa-to-liberdade-peer01"
  }
}