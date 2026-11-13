namespace Bozras.Application.DTOs.Products.Request;

public class UpdateProductRequest : CreateProductRequest
{
    public bool IsActive { get; set; } = true;
}