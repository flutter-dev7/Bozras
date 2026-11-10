namespace Bozras.Application.DTOs.Suppliers.Response;

public class SubscriptionPaymentResponse
{
    public Guid Id { get; set; }
    public decimal Amount { get; set; }
    public string Method { get; set; } = string.Empty;
    public string? PlanName { get; set; }
    public DateOnly PeriodFrom { get; set; }
    public DateOnly PeriodTo { get; set; }
    public string? Note { get; set; }
    public DateTime CreatedAt { get; set; }
}