using Bozras.Application.Common;

namespace Bozras.Application.DTOs.Payments.Request;

public class PaymentQueryRequest : PaginationRequest
{
    public Guid? ShopId { get; set; }
}