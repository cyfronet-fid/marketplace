describe('Sanity', () => {
    it('check intro box existence', () => {
        cy.visit('/');
        cy.get('.autocomplete-input').first().type("test");
        cy.get('.intro-box')
            .first()
            .find('a')
            .should("exist")
            .click();
        cy.location('pathname').should('be.eq', "/search/all");
    })
})