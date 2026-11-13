using System.ComponentModel.DataAnnotations;

namespace Bozras.Application.DTOs.Stock.Request;

public class ReceiveStockRequest
{
    [Required]
    public Guid ProductId { get; set; }

    [Range(1, 1000000)]
    public int Quantity { get; set; }

    [StringLength(300)]
    public string? Comment { get; set; }
}