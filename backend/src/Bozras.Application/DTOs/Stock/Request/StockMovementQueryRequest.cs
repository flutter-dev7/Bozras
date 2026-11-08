using Bozras.Application.Common;

namespace Bozras.Application.DTOs.Stock.Request;

public class StockMovementQueryRequest : PaginationRequest
{
    public Guid? ProductId { get; set; }
}