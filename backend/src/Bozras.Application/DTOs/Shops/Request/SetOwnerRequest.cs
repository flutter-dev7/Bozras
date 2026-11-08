using System.ComponentModel.DataAnnotations;

namespace Bozras.Application.DTOs.Shops.Request;

public class SetOwnerRequest
{
    [StringLength(20)]
    public string? OwnerPhone { get; set; }
}