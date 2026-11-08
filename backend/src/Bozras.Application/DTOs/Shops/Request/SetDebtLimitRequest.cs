using System.ComponentModel.DataAnnotations;

namespace Bozras.Application.DTOs.Shops.Request;

public class SetDebtLimitRequest
{
    [Range(typeof(decimal), "0", "100000000")]
    public decimal? DebtLimit { get; set; }
}