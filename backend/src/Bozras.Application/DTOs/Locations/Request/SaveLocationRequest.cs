using System.ComponentModel.DataAnnotations;
using Bozras.Domain.Enums;

namespace Bozras.Application.DTOs.Locations.Request;

public class SaveLocationRequest
{
    [Required, StringLength(150)]
    public string Name { get; set; } = string.Empty;

    public LocationType Type { get; set; }

    public Guid? ParentId { get; set; }

    public bool IsActive { get; set; } = true;
}