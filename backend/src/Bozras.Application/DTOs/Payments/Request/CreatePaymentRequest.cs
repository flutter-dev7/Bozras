using System.ComponentModel.DataAnnotations;
using Bozras.Domain.Enums;

namespace Bozras.Application.DTOs.Payments.Request;

public class CreatePaymentRequest
{
    public Guid ShopId { get; set; }

    public Guid? OrderId { get; set; }

    [Range(typeof(decimal), "0.01", "100000000", ParseLimitsInInvariantCulture = true, ConvertValueInInvariantCulture = true)]
    public decimal Amount { get; set; }

    [EnumDataType(typeof(PaymentMethod))]
    public PaymentMethod Method { get; set; } = PaymentMethod.Cash;
}