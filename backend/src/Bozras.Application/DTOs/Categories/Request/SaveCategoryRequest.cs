using System.ComponentModel.DataAnnotations;

namespace Bozras.Application.DTOs.Categories.Request;

public class SaveCategoryRequest
{
    [Required]
    [StringLength(100)]
    public string Name { get; set; } = string.Empty;
}