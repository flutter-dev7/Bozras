using System.ComponentModel.DataAnnotations;
using Bozras.Domain.Enums;

namespace Bozras.Application.DTOs.Suppliers.Request;

public class RecordSubscriptionPaymentRequest
{
    [Range(0.01, 100000000)]
    public decimal Amount { get; set; }

    public PaymentMethod Method { get; set; }

    [Range(1, 24)]
    public int Months { get; set; } = 1;

    public Guid? PlanId { get; set; }

    [StringLength(300)]
    public string? Note { get; set; }
}