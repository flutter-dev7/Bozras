using Non.Domain.Common;
using Non.Domain.Enums;

namespace Non.Domain.Entities;

public class SubscriptionPayment : BaseEntity
{
    public Guid SupplierId { get; set; }
    public Supplier? Supplier { get; set; }

    public Guid? PlanId { get; set; }
    public Plan? Plan { get; set; }

    public decimal Amount { get; set; }
    public PaymentMethod Method { get; set; }

    public DateOnly PeriodFrom { get; set; }
    public DateOnly PeriodTo { get; set; }

    public string? Note { get; set; }
    public Guid? CreatedByUserId { get; set; }
}