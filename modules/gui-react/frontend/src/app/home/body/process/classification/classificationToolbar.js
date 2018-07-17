import PropTypes from 'prop-types'
import React from 'react'
import {PanelWizard} from 'widget/panel'
import {PanelButton, Toolbar} from 'widget/toolbar'
import {recipePath} from './classificationRecipe'
import styles from './classificationToolbar.module.css'
import Source from './source/source'

export default class ClassificationToolbar extends React.Component {
    render() {
        const {recipeId} = this.props
        const statePath = recipePath(recipeId, 'ui')
        return (
            <PanelWizard
                panels={['mosaic', 'trainingData']}
                statePath={statePath}>
                <Toolbar
                    statePath={statePath}
                    vertical bottom right
                    className={styles.bottom}>
                    <PanelButton
                        name='mosaic'
                        label='process.classification.panel.source.button'
                        tooltip='process.classification.panel.source'>
                        <Source recipeId={recipeId}/>
                    </PanelButton>

                    <PanelButton
                        name='trainingData'
                        label='process.classification.panel.trainingData.button'
                        tooltip='process.classification.panel.trainingData'>
                        <Source recipeId={recipeId}/>
                    </PanelButton>
                </Toolbar>
            </PanelWizard>
        )
    }
}

ClassificationToolbar.propTypes = {
    recipeId: PropTypes.string.isRequired
}