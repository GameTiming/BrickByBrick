class_name MarketOffer
extends Resource

var id: String

var material: ConstructionMaterial
var seller: SellerData

var negotiated_price: int
var asked_question_ids: Array[String] = []

var negotiation_round: int = 0
var negotiation_closed: bool = false
