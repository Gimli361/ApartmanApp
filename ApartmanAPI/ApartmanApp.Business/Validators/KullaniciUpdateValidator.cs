using ApartmanApp.Business.DTOs.Kullanici;
using FluentValidation;

namespace ApartmanApp.Business.Validators;

public class KullaniciUpdateValidator : AbstractValidator<KullaniciUpdateDto>
{
    public KullaniciUpdateValidator()
    {
        RuleFor(x => x.Ad)
            .NotEmpty().WithMessage("Ad boş olamaz.")
            .MaximumLength(50);

        RuleFor(x => x.Soyad)
            .NotEmpty().WithMessage("Soyad boş olamaz.")
            .MaximumLength(50);

        RuleFor(x => x.DaireNo)
            .NotEmpty().WithMessage("Daire No boş olamaz.")
            .MaximumLength(20);

        RuleFor(x => x.BlokNo)
            .MaximumLength(20)
            .When(x => !string.IsNullOrEmpty(x.BlokNo));
    }
}
