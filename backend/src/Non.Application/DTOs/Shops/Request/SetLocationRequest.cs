using System.ComponentModel.DataAnnotations;

namespace Non.Application.DTOs.Shops.Request;

public class SetLocationRequest
{
    [Range(-90, 90)]
    public double? Latitude { get; set; }

    [Range(-180, 180)]
    public double? Longitude { get; set; }
}