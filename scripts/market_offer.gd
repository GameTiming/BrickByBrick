class_name MarketOffer
extends Resource

var id: String

var material: ConstructionMaterial
var seller: SellerData

var negotiated_price: int
var asked_question_ids: Array[String] = []
