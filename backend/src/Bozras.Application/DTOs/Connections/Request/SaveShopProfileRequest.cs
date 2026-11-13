using System.ComponentModel.DataAnnotations;

namespace Bozras.Application.DTOs.Connections.Request;

public class SaveShopProfileRequest
{
    [Required, MaxLength(150)]
    public string Name { get; set; } = string.Empty;

    [Required, MaxLength(300)]
    public string Address { get; set; } = string.Empty;

    [Required, MaxLength(30)]
    public string Phone { get; set; } = string.Empty;

    [MaxLength(150)]
    public string? ContactName { get; set; }

    [Required]
    public Guid? LocationId { get; set; }

    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
}