# ドメインのエラーを、HTTP のステータスとエラーコードに変える。
# この対応表はプレゼンテーション層だけが持ち、ドメイン層は HTTP を知らない。
module DomainErrorResponses
  def domain_error_response(error)
    case error
    when Ticketing::Inventory::NotEnoughSeats then [ :conflict, "not_enough_seats" ]
    when Ticketing::Reservation::AlreadyReserved then [ :conflict, "already_reserved" ]
    when Ticketing::SalesPeriod::Closed then [ :conflict, "sales_closed" ]
    when Ticketing::NotFound then [ :not_found, "not_found" ]
    else [ :unprocessable_content, "business_rule_violation" ]
    end
  end
end
