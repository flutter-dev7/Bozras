using Non.Application.Common;

namespace Non.Application.DTOs.Stock.Request;

public class StockMovementQueryRequest : PaginationRequest
{
    public Guid? ProductId { get; set; }
}